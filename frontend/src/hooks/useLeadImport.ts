import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { leadImportService } from '@/services/lead-import.service';
import {
    MappingSubmission,
    ExecuteImportRequest,
    TemplateCreate,
    TemplateUpdate,
} from '@/types/lead-import';
import { toast } from 'sonner';

// ========== Phase 1: Upload & Analyze ==========

export const useUploadFile = () => {
    return useMutation({
        mutationFn: (file: File) => leadImportService.uploadAndAnalyze(file),
        onError: (error: any) => {
            toast.error(error.response?.data?.detail || 'Failed to upload file');
        },
    });
};

// ========== Phase 2: Submit Mapping ==========

export const useSubmitMapping = () => {
    return useMutation({
        mutationFn: ({
            sessionId,
            mappingData,
        }: {
            sessionId: number;
            mappingData: MappingSubmission;
        }) => leadImportService.submitMapping(sessionId, mappingData),
        onError: (error: any) => {
            toast.error(error.response?.data?.detail || 'Failed to submit mapping');
        },
    });
};

// ========== Phase 3: Get Preview ==========

export const useImportPreview = (sessionId: number | null, enabled: boolean = true) => {
    return useQuery({
        queryKey: ['import-preview', sessionId],
        queryFn: () => leadImportService.getPreview(sessionId!),
        enabled: enabled && !!sessionId,
        retry: false,
    });
};

// ========== Phase 4: Get Duplicates ==========

export const useImportDuplicates = (sessionId: number | null, enabled: boolean = true) => {
    return useQuery({
        queryKey: ['import-duplicates', sessionId],
        queryFn: () => leadImportService.getDuplicates(sessionId!),
        enabled: enabled && !!sessionId,
        retry: false,
    });
};

// ========== Phase 5: Execute Import ==========

export const useExecuteImport = () => {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: ({
            sessionId,
            request,
        }: {
            sessionId: number;
            request: ExecuteImportRequest;
        }) => leadImportService.executeImport(sessionId, request),
        onSuccess: () => {
            // Invalidate leads list to show new imports
            queryClient.invalidateQueries({ queryKey: ['leads'] });
        },
        onError: (error: any) => {
            toast.error(error.response?.data?.detail || 'Failed to execute import');
        },
    });
};

// ========== Session Management ==========

export const useImportSession = (sessionId: number | null, enabled: boolean = true) => {
    return useQuery({
        queryKey: ['import-session', sessionId],
        queryFn: () => leadImportService.getSessionStatus(sessionId!),
        enabled: enabled && !!sessionId,
        refetchInterval: 5000, // Poll every 5 seconds for status updates
        retry: false,
    });
};

export const useDeleteSession = () => {
    return useMutation({
        mutationFn: (sessionId: number) => leadImportService.deleteSession(sessionId),
        onSuccess: () => {
            toast.success('Import session deleted');
        },
        onError: (error: any) => {
            toast.error(error.response?.data?.detail || 'Failed to delete session');
        },
    });
};

// ========== Templates ==========

export const useImportTemplates = () => {
    return useQuery({
        queryKey: ['import-templates'],
        queryFn: () => leadImportService.listTemplates(),
    });
};

export const useCreateTemplate = () => {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: (data: TemplateCreate) => leadImportService.createTemplate(data),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['import-templates'] });
            toast.success('Template saved successfully');
        },
        onError: (error: any) => {
            toast.error(error.response?.data?.detail || 'Failed to save template');
        },
    });
};

export const useUpdateTemplate = () => {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: ({
            templateId,
            data,
        }: {
            templateId: number;
            data: TemplateUpdate;
        }) => leadImportService.updateTemplate(templateId, data),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['import-templates'] });
            toast.success('Template updated successfully');
        },
        onError: (error: any) => {
            toast.error(error.response?.data?.detail || 'Failed to update template');
        },
    });
};

export const useDeleteTemplate = () => {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: (templateId: number) => leadImportService.deleteTemplate(templateId),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['import-templates'] });
            toast.success('Template deleted successfully');
        },
        onError: (error: any) => {
            toast.error(error.response?.data?.detail || 'Failed to delete template');
        },
    });
};
